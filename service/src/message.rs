//! Passing messages to and from the worker.

use futures::prelude::*;
use lapin::{
    channel::{Channel, QueueDeclareOptions},
    client::{Client, ConnectionOptions},
    queue::Queue,
    types::FieldTable,
};
use std::io;
use tokio::{
    self,
    net::TcpStream,
};

// TODO: read address from configuration/command line.
static ADDRESS: &str = "127.0.0.1:5672";

static QUEUE: &str = "pdf";

#[async]
pub fn connect(heartbeat: bool) -> io::Result<(Channel<TcpStream>, Queue)> {
    let addr = ADDRESS.parse().unwrap();
    let stream = await!(TcpStream::connect(&addr))?;
    let (client, hb) = await!(Client::connect(
        stream, ConnectionOptions::default()))?;

    if heartbeat {
        // TODO: do something with errors.
        tokio::spawn(hb.map_err(|_| ()));
    }

    let channel = await!(client.create_channel())?;
    let queue = await!(channel.queue_declare(QUEUE, QueueDeclareOptions {
        durable: true,
        ..QueueDeclareOptions::default()
    }, FieldTable::new()))?;

    Ok((channel, queue))
}
