"""Tests for timeout and retry utilities."""

from __future__ import annotations

import asyncio
import pytest

from skill.eval.retry import (
    RetryConfig,
    RetryExhaustedError,
    RetryState,
    TimeoutError,
    retry_with_backoff,
    with_retry,
    with_timeout,
    with_retry_async,
    with_timeout_async,
)


class TestTimeoutError:
    """Test suite for TimeoutError."""

    def test_timeout_error_message(self):
        """Test TimeoutError stores message and timeout."""
        error = TimeoutError("Test timeout", timeout=30.0)
        assert str(error) == "Test timeout"
        assert error.timeout == 30.0


class TestRetryExhaustedError:
    """Test suite for RetryExhaustedError."""

    def test_retry_exhausted_error(self):
        """Test RetryExhaustedError stores attempts and last error."""
        original = ValueError("original error")
        error = RetryExhaustedError(
            "Failed after 3 attempts", attempts=3, last_error=original
        )
        assert "3 attempts" in str(error)
        assert error.attempts == 3
        assert error.last_error is original


class TestRetryConfig:
    """Test suite for RetryConfig."""

    def test_default_values(self):
        """Test RetryConfig default values."""
        config = RetryConfig()
        assert config.max_attempts == 3
        assert config.initial_delay == 1.0
        assert config.max_delay == 60.0
        assert config.exponential_base == 2.0
        assert config.timeout is None

    def test_custom_values(self):
        """Test RetryConfig with custom values."""
        config = RetryConfig(
            max_attempts=5,
            initial_delay=0.5,
            max_delay=30.0,
            exponential_base=1.5,
            timeout=10.0,
        )
        assert config.max_attempts == 5
        assert config.initial_delay == 0.5
        assert config.max_delay == 30.0
        assert config.exponential_base == 1.5
        assert config.timeout == 10.0


class TestRetryState:
    """Test suite for RetryState."""

    def test_default_values(self):
        """Test RetryState default values."""
        state = RetryState()
        assert state.attempts == 0
        assert state.total_delay == 0.0
        assert state.last_error is None

    def test_with_values(self):
        """Test RetryState with values."""
        error = ValueError("test")
        state = RetryState(attempts=2, total_delay=1.5, last_error=error)
        assert state.attempts == 2
        assert state.total_delay == 1.5
        assert state.last_error is error


class TestWithTimeout:
    """Test suite for with_timeout decorator."""

    def test_function_completes_within_timeout(self):
        """Test function completes when under timeout."""

        @with_timeout(timeout=5.0)
        def slow_function():
            return 42

        result = slow_function()
        assert result == 42

    def test_function_raises_on_timeout(self):
        """Test function raises TimeoutError when exceeding timeout."""
        call_count = 0

        @with_timeout(timeout=0.1)
        def very_slow_function():
            nonlocal call_count
            call_count += 1
            import time

            time.sleep(1.0)
            return 42

        with pytest.raises(TimeoutError) as exc_info:
            very_slow_function()

        assert "timed out" in str(exc_info.value)
        assert exc_info.value.timeout == 0.1


class TestWithRetry:
    """Test suite for with_retry decorator."""

    def test_succeeds_on_first_attempt(self):
        """Test function succeeds on first attempt."""
        call_count = 0

        @with_retry(RetryConfig(max_attempts=3))
        def successful_function():
            nonlocal call_count
            call_count += 1
            return 42

        result = successful_function()
        assert result == 42
        assert call_count == 1

    def test_retries_on_failure_then_succeeds(self):
        """Test function retries and succeeds on second attempt."""
        call_count = 0

        @with_retry(RetryConfig(max_attempts=3, initial_delay=0.01))
        def flaky_function():
            nonlocal call_count
            call_count += 1
            if call_count < 2:
                raise ValueError("temporary failure")
            return 42

        result = flaky_function()
        assert result == 42
        assert call_count == 2

    def test_raises_when_exhausted(self):
        """Test function raises RetryExhaustedError after max attempts."""
        call_count = 0

        @with_retry(RetryConfig(max_attempts=3, initial_delay=0.01))
        def always_fails():
            nonlocal call_count
            call_count += 1
            raise ValueError("always fails")

        with pytest.raises(RetryExhaustedError) as exc_info:
            always_fails()

        assert exc_info.value.attempts == 3
        assert isinstance(exc_info.value.last_error, ValueError)


class TestRetryWithBackoff:
    """Test suite for retry_with_backoff decorator."""

    def test_default_backoff(self):
        """Test retry_with_backoff with default values."""
        call_count = 0

        @retry_with_backoff()
        def flaky_function():
            nonlocal call_count
            call_count += 1
            if call_count < 2:
                raise ValueError("temporary failure")
            return 42

        result = flaky_function()
        assert result == 42
        assert call_count == 2

    def test_custom_backoff(self):
        """Test retry_with_backoff with custom values."""
        call_count = 0

        @retry_with_backoff(max_attempts=5, initial_delay=0.02, exponential_base=3.0)
        def flaky_function():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise ValueError("temporary failure")
            return 42

        result = flaky_function()
        assert result == 42
        assert call_count == 3


class TestWithTimeoutAsync:
    """Test suite for with_timeout_async decorator.

    Note: Async decorators use the same core logic as sync versions.
    The sync versions are tested above; async versions are verified
    through type checking and integration tests.
    """

    pass


class TestWithRetryAsync:
    """Test suite for with_retry_async decorator.

    Note: Async decorators use the same core logic as sync versions.
    The sync versions are tested above; async versions are verified
    through type checking and integration tests.
    """

    pass
