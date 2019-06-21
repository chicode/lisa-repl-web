import { Elm } from "./Main.elm";
import * as lisavm from "@chicode/lisa-vm";
import "../css/app.scss";
import CodeMirror from "codemirror";
import "codemirror/lib/codemirror.css";

const app = Elm.Main.init();

const processLisa = source =>
  new Promise((res, rej) => {
    app.ports.out.subscribe(sub);
    app.ports.incoming.send(source);
    function sub(result) {
      app.ports.out.unsubscribe(sub);

      if (result.status === "ok") {
        res(result.result);
      } else {
        rej(result.error);
      }
    }
  });

const editor = CodeMirror.fromTextArea(document.getElementById("codemirror"), {
  extraKeys: {
    Tab: cm => {
      cm.replaceSelection("   ", "end");
    }
  }
});

const output = document.getElementById("output");
const errors = document.getElementById("errors");

const programScope = lisavm.initProgram();

let mark;

const evalLisa = async () => {
  errors.textContent = "";
  if (mark) mark.clear();
  const code = editor.getValue();
  try {
    var program = await processLisa(code);
    let result = lisavm.values.none;
    for (const replExpr of program) {
      switch (replExpr.type) {
        case "expression":
          result = lisavm.evalExpression(programScope, replExpr.expr);
          break;
        case "definition":
          programScope.vars[replExpr.name] = lisavm.evalExpression(
            programScope,
            replExpr.value
          );
      }
    }
    const repr =
      result.type === "none"
        ? "none"
        : JSON.stringify(lisavm.valueToJs(result));

    output.textContent = repr;
  } catch (err) {
    console.error(err);
    mark = editor.getDoc().markText(
      {
        line: err.location.startRow - 1,
        ch: err.location.startCol - 1
      },
      {
        line: err.location.endRow - 1,
        ch: err.location.endCol - 1
      },
      { className: "uh-oh" }
    );
    output.textContent = "";
    errors.textContent = err.msg || err.message;
  }
};

document.getElementById("evaluate").addEventListener("click", evalLisa);
