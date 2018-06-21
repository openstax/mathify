#![feature(proc_macro, generators)]

extern crate futures_await as futures;
extern crate lapin_futures as lapin;
extern crate structopt;
extern crate tokio;

pub mod cli;
pub mod client;
pub mod message;
pub mod worker;
