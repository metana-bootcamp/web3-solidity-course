function run(bytecode) {
    var len = bytecode.length;
    if (!len || len % 2)
        throw new Error("Bad input");
    var hl = len >> 1;
    
    var code = new Array(hl);
    for (var i = 0; i < hl; i++) {
        code[i] = parseInt(bytecode.substr(i * 2, 2), 16);
    }

    var codeSize = code.length;
    var stack = [];
    var pc = -1;

    while (++pc < codeSize) {
        switch (code[pc]) {
            case 1:
                var num = (code[++pc] << 24) | (code[++pc] << 16) | (code[++pc] << 8) | code[++pc];
                stack.push(num);
                console.log("PUSH: %d", num);
                break;
            case 2:
                if (stack.length < 2)
                    throw new Error("Stack underflow");
                var a = stack.pop(), b = stack.pop();
                var sum = a + b;
                stack.push(sum);
                console.log("ADD: %d + %d = %d", a, b, sum);
                break;
            default:
                throw new Error("Bad instruction");
        }
        console.log("Stack:", stack);
    }
    console.log("Done");
}

run("60016003015000");