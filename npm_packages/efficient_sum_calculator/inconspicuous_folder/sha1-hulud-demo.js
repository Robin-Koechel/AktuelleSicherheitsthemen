function preinstall() {
  console.log("+++++++++++++++++++++++");
  console.log("+ Pre-Install Routine +");
  console.log("+++++++++++++++++++++++\n");
  console.log("This script can do whatever it wants...\n");
}

function install() {
  console.log("+++++++++++++++++++");
  console.log("+ Install Routine +");
  console.log("+++++++++++++++++++\n");
  console.log("This script can do whatever it wants...\n");
}

function postinstall() {
  console.log("++++++++++++++++++++++++");
  console.log("+ Post-Install Routine +");
  console.log("++++++++++++++++++++++++\n");
  console.log("This script can do whatever it wants...\n");
}

const stage = process.argv[2];

if (stage === "preinstall") {
  preinstall();
} else if (stage === "install") {
  install();
} else if (stage === "postinstall") {
  postinstall();
} else {
  log("manual_execution", {
    message:
      "This is a demo-only script. Use one of: preinstall, install, postinstall.",
  });
}
