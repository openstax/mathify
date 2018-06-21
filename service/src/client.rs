use futures::prelude::*;
use lapin::channel::BasicProperties;
use std::io;

use message;

#[async]
pub fn send() -> io::Result<()> {
    let (channel, _) = await!(message::connect(false))?;

    let r = await!(channel.basic_publish("", "pdf", b"hello!", Default::default(), BasicProperties {
        // 2 = persistent, see https://www.rabbitmq.com/tutorials/tutorial-two-python.html
        delivery_mode: Some(2),
        ..BasicProperties::default()
    }))?;
    println!("message delivered: {:?}", r);

    Ok(())
}
