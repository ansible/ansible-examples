use anyhow::{anyhow, Context};
use serde::{Deserialize, Serialize};
use std::{env, fs, process};

fn default_name_arg() -> String {
    String::from("World")
}
#[derive(Deserialize)]
struct ModuleArgs {
    #[serde(default = "default_name_arg")]
    name: String,
}

#[derive(Clone, Serialize)]
struct Response {
    msg: String,
    changed: bool,
    failed: bool,
}

fn main() {
    let (response, code) = match run_module() {
        Ok(response) => (response, 0),
        Err(err) => (
            Response {
                msg: err.to_string(),
                changed: false,
                failed: true,
            },
            1,
        ),
    };
    println!("{}", serde_json::to_string(&response).unwrap());
    process::exit(code);
}

fn run_module() -> anyhow::Result<Response> {
    let input_filename = env::args().nth(1).ok_or(anyhow!(
        "module '{}' expects exactly one argument!",
        env::args().next().unwrap()
    ))?;
    let json_input = fs::read_to_string(&input_filename)
        .with_context(|| format!("Could not read file '{}'", input_filename))?;
    let module_args: ModuleArgs = serde_json::from_str(&json_input)
        .with_context(|| format!("Malformed input JSON module arguments"))?;
    Ok(Response {
        msg: format!("Hello, {}!", module_args.name),
        changed: true,
        failed: false,
    })
}
