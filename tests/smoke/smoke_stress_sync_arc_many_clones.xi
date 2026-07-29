module smoke_stress_sync_arc_many_clones
    use xiom.sync;

    fn main() -> Int {
        var a = sync.Arc.new(300);
        var b = a.clone();
        var c = b.clone();
        var d = c.clone();
        var v = d.get();
        var count = a.strong_count();
        d.drop();
        c.drop();
        b.drop();
        a.drop();
        if v == 300 {
            if count == 4 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
    }
}
