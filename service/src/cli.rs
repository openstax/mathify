use failure::Error;
use futures::Future;
use std::io;
use structopt::StructOpt;
use tokio::runtime::Runtime;

use self::Args::*;
use super::{
    client::send,
    worker::worker,
};

#[derive(StructOpt)]
enum Args {
    /// Spin up a worker to consume tasks
    #[structopt(name = "worker")]
    Worker {
    },
    /// Send a new task to be processed
    #[structopt(name = "send")]
    Send {
        /// File to bake
        file: String,
    },
}

pub fn main() -> Result<(), Error> {
    let args = Args::from_args();

    match args {
        Worker {} => spin(worker()),
        Send { file } => spin(send(file.into_bytes())),
    }
}

fn spin<F>(f: F) -> Result<F::Item, Error>
where
    F: Future<Error = Error> + ::std::marker::Send + 'static,
    F::Item: ::std::marker::Send + 'static,
{
    Runtime::new()?.block_on(f)
}
