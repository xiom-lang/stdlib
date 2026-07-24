module xiom.bench.stats

fn stats_mean(data: &Vec[Int]) -> Int
  requires: data.len() >= 0
  ensures: result >= 0 || data.len() == 0
{
  if data.len() == 0 {
    0
  } else {
    stats_sum(data, 0) / data.len()
  }
}

fn stats_sum(data: &Vec[Int], idx: Int) -> Int
  requires: idx >= 0
  requires: idx <= data.len()
{
  if idx >= data.len() {
    0
  } else {
    data[idx] + stats_sum(data, idx + 1)
  }
}

fn stats_median(data: &Vec[Int]) -> Int
  requires: data.len() >= 0
{
  let len = data.len();
  if len == 0 {
    0
  } elif len % 2 == 1 {
    data[len / 2]
  } else {
    (data[len / 2 - 1] + data[len / 2]) / 2
  }
}

fn stats_stddev(data: &Vec[Int], mean: Int) -> Int
  requires: data.len() >= 0
{
  if data.len() == 0 {
    0
  } else {
    let variance = stats_variance_sum(data, mean, 0) / data.len();
    int_sqrt(variance)
  }
}

fn stats_variance_sum(data: &Vec[Int], mean: Int, idx: Int) -> Int
  requires: idx >= 0
  requires: idx <= data.len()
{
  if idx >= data.len() {
    0
  } else {
    let diff = data[idx] - mean;
    (diff * diff) + stats_variance_sum(data, mean, idx + 1)
  }
}

fn int_sqrt(n: Int) -> Int
  requires: n >= 0
  ensures: result >= 0
  ensures: result * result <= n && (result + 1) * (result + 1) > n
{
  if n <= 1 {
    n
  } else {
    int_sqrt_iter(n, n / 2)
  }
}

fn int_sqrt_iter(n: Int, guess: Int) -> Int
  requires: n >= 0
  requires: guess >= 0
{
  let next = (guess + n / guess) / 2;
  if next >= guess {
    guess
  } else {
    int_sqrt_iter(n, next)
  }
}

fn stats_percentile(data: &Vec[Int], p: Int) -> Int
  requires: data.len() >= 0
  requires: p >= 0 && p <= 100
{
  if data.len() == 0 {
    0
  } elif p <= 0 {
    data[0]
  } elif p >= 100 {
    data[data.len() - 1]
  } else {
    let idx = (p * data.len()) / 100;
    data[idx]
  }
}
