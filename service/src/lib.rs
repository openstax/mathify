#![feature(proc_macro, generators)]

extern crate failure;
extern crate futures_await as futures;
extern crate hyper;
extern crate hyper_tls;
extern crate lapin_futures as lapin;
extern crate structopt;
extern crate tempfile;
extern crate tokio;

#[macro_use] extern crate log;

pub mod cli;
pub mod client;
pub mod message;
pub mod worker;
