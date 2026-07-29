module smoke_stress_sync_arc_new_clone
    use xiom.sync;

    fn main() -> Int {
        var a = sync.Arc.new(100);
        var b = a.clone();
        var v = b.get();
        b.drop();
        a.drop();
        if v == 100 {
            return 0;
        } else {
            return 1;
        }
    }
}
