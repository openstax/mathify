use failure::Error;
use futures::prelude::*;
use hyper::{
    client::HttpConnector,
    Body,
    Client,
    Uri,
};
use hyper_tls::HttpsConnector;
use lapin::{
    channel::BasicQosOptions,
    types::FieldTable,
};
use std::{
    fs::File,
    io::{self, Write},
    process::Command,
};
use tempfile::tempdir;

use message;

/// Sequentially execute scheduled jobs.
#[async]
pub fn worker() -> Result<(), Error> {
    let (channel, queue) = await!(message::connect(true))?;

    await!(channel.basic_qos(BasicQosOptions {
        prefetch_count: 1,
        ..BasicQosOptions::default()
    }))?;

    let connector = HttpsConnector::new(2)?;
    let client = Client::builder().build(connector);

    info!("started worker");

    #[async]
    for message in await!(channel.basic_consume(&queue, "worker", Default::default(), FieldTable::new()))? {
        let uri = Uri::from_shared(message.data.into())?;
        info!("work received: {}", uri);

        match await!(process(client.clone(), uri)) {
            Ok(_) => (),
            Err(err) => error!("failed to process job: {}", err),
        }

        await!(channel.basic_ack(message.delivery_tag))?;
    }

    Ok(())
}

#[async]
pub fn process(client: Client<HttpsConnector<HttpConnector>, Body>, source: Uri) -> Result<(), Error> {
    let res = await!(client.get(source))?;

    if !res.status().is_success() {
        // TODO: do something
    }

    let dir = tempdir()?;

    let input_path = dir.path().join("input.xhtml");
    let output_path = dir.path().join("output.pdf");

    let mut input = File::create(&input_path)?;

    #[async]
    for chunk in res.into_body() {
        input.write_all(&chunk)?;
    }

    // TODO: collect stdout/err
    let process = Command::new("sh")
        .arg("bake.sh")
        .env("BAKE_INPUT", input_path)
        .env("BAKE_OUTPUT", output_path)
        .status()?;

    Ok(())
}
