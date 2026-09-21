import numpy as np
from pykeen.triples import TriplesFactory
from src.step3_train_kge import train_transe, extract_eval_metrics


def test_train_transe_returns_valid_metrics():
    rng = np.random.default_rng(0)
    entities = [f"e{i}" for i in range(12)]
    relations = ["r0", "r1", "r2"]
    triples = np.array([
        [rng.choice(entities), rng.choice(relations), rng.choice(entities)]
        for _ in range(60)
    ])
    tf = TriplesFactory.from_labeled_triples(triples)
    result = train_transe(tf, train_ratio=0.8, num_epochs=5, random_seed=0)
    metrics = extract_eval_metrics(result)
    for key in ["mrr", "hits_at_1", "hits_at_3", "hits_at_10"]:
        assert 0.0 <= metrics[key] <= 1.0
