extern crate bakedpdf;
extern crate env_logger;

fn main() {
    env_logger::init();

    bakedpdf::cli::main().unwrap();
}
