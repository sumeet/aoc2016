WebAssembly
    .instantiateStreaming(fetch('day8.wasm'), {
        imports: { log: console.log },
    }).then(obj => {
        obj.instance.exports.add(2, 9);
    });
