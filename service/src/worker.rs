use futures::prelude::*;
use lapin::{
    channel::BasicQosOptions,
    types::FieldTable,
};
use std::io;

use message;

#[async]
pub fn worker() -> io::Result<()> {
    let (channel, queue) = await!(message::connect(true))?;

    await!(channel.basic_qos(BasicQosOptions {
        prefetch_count: 1,
        ..BasicQosOptions::default()
    }))?;

    #[async]
    for message in await!(channel.basic_consume(&queue, "worker", Default::default(), FieldTable::new()))? {
        debug!("message: {:?}", message);
        await!(channel.basic_ack(message.delivery_tag))?;
    }

    Ok(())
}
