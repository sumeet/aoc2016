(module 
    ;; (memory 1)
    (func $hello (import "imports" "logStr") (param string))
    ;; (func $log (import "imports" "log") (param i32))
    (func $add (param $lhs i32) (param $rhs i32) (result i32)
        get_local $lhs
        get_local $rhs
        (call $log (i32.add))

        get_local $lhs
        get_local $rhs
        i32.add
    )
    (export "add" (func $add))
)