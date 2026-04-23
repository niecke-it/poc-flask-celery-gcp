import math
import time
import numpy as np
from celery_app import celery_app


@celery_app.task(bind=True, name="tasks.monte_carlo_pi")
def monte_carlo_pi(self, iterations: int = 10_000_000):
    """
    Estimate Pi via Monte Carlo: randomly sample points in [-1,1]^2,
    count fraction inside the unit circle, multiply by 4.

    CPU-bound due to numpy random generation + vectorised distance check.
    Reports progress via Celery state updates every chunk.
    """
    chunk_size = 500_000
    inside = 0
    processed = 0
    start = time.time()

    for _ in range(0, iterations, chunk_size):
        current = min(chunk_size, iterations - processed)
        x = np.random.uniform(-1.0, 1.0, current)
        y = np.random.uniform(-1.0, 1.0, current)
        inside += int(np.sum(x**2 + y**2 <= 1.0))
        processed += current

        self.update_state(
            state="PROGRESS",
            meta={
                "processed": processed,
                "total": iterations,
                "percent": round(100.0 * processed / iterations, 1),
                "pi_so_far": round(4.0 * inside / processed, 6),
            },
        )

    elapsed = time.time() - start
    pi_estimate = 4.0 * inside / iterations

    return {
        "pi_estimate": round(pi_estimate, 8),
        "pi_actual": round(math.pi, 8),
        "error": round(abs(pi_estimate - math.pi), 8),
        "iterations": iterations,
        "elapsed_seconds": round(elapsed, 3),
        "throughput_per_sec": int(iterations / elapsed),
    }
