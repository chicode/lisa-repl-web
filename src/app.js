import Elm from "./Main.elm";
import * as lisavm from "@chicode/lisa-vm";
import * as repl from "repl";
import { callbackify } from "util";
import '../css/app.scss'
import CodeMirror from 'codemirror'

const app = Elm.Main.init({
  node: document.getElementById('root'),
  windowWidth: window.innerWidth,
})

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

const programScope = lisavm.initProgram();
// programScope.parent.vars["-last"] = {
//   type: "const",
//   get value() {
//     return rep.last || { type: "none" };
//   }
// };
const rep = repl.start({
  ignoreUndefined: true,
  eval: callbackify(async (evalCmd, _context, _file) => {
    try {
      var program = await processLisa(evalCmd);
    } catch (e) {
      const err = new SyntaxError(e.msg);
      throw e.recoverable ? new repl.Recoverable(err) : err;
    }
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
    rep.last = result;
    return result.type !== "none" ? lisavm.valueToJs(result) : undefined;
  })
});

