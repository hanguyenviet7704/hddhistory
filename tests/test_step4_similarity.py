import numpy as np
from src.step4_similarity import cosine_similarity


def test_cosine_similarity_identical_vectors_is_one():
    v = np.array([1.0, 2.0, 3.0])
    assert abs(cosine_similarity(v, v) - 1.0) < 1e-9


def test_cosine_similarity_orthogonal_vectors_is_zero():
    u = np.array([1.0, 0.0])
    v = np.array([0.0, 1.0])
    assert abs(cosine_similarity(u, v)) < 1e-9


def test_cosine_similarity_opposite_vectors_is_negative_one():
    u = np.array([1.0, 0.0])
    v = np.array([-1.0, 0.0])
    assert abs(cosine_similarity(u, v) + 1.0) < 1e-9
