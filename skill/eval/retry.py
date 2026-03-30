"""Timeout and retry utilities for robust execution."""

from __future__ import annotations

import asyncio
import functools
import logging
import time
from dataclasses import dataclass, field
from typing import Any, Callable, Coroutine, TypeVar

logger = logging.getLogger(__name__)

T = TypeVar("T")


class TimeoutError(Exception):
    """Raised when an operation times out."""

    def __init__(self, message: str, timeout: float) -> None:
        super().__init__(message)
        self.timeout = timeout


class RetryExhaustedError(Exception):
    """Raised when all retry attempts are exhausted."""

    def __init__(self, message: str, attempts: int, last_error: Exception) -> None:
        super().__init__(message)
        self.attempts = attempts
        self.last_error = last_error


@dataclass
class RetryConfig:
    """Configuration for retry behavior."""

    max_attempts: int = 3
    initial_delay: float = 1.0
    max_delay: float = 60.0
    exponential_base: float = 2.0
    timeout: float | None = None


@dataclass
class RetryState:
    """State tracking for retry operations."""

    attempts: int = 0
    total_delay: float = 0.0
    last_error: Exception | None = None


def with_timeout(
    timeout: float, message: str | None = None
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator to add timeout to a synchronous function.

    Args:
        timeout: Timeout in seconds.
        message: Custom error message.

    Returns:
        Decorated function with timeout.
    """

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            start = time.monotonic()
            result = func(*args, **kwargs)
            elapsed = time.monotonic() - start
            if elapsed > timeout:
                raise TimeoutError(
                    message or f"{func.__name__} timed out after {timeout}s",
                    timeout=timeout,
                )
            return result

        return wrapper

    return decorator


def with_retry(config: RetryConfig | None = None) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Decorator to add retry behavior to a synchronous function.

    Args:
        config: Retry configuration. Uses defaults if None.

    Returns:
        Decorated function with retry.
    """
    if config is None:
        config = RetryConfig()

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> T:
            state = RetryState()
            delay = config.initial_delay

            while state.attempts < config.max_attempts:
                state.attempts += 1
                try:
                    if config.timeout is not None:
                        start = time.monotonic()
                        result = func(*args, **kwargs)
                        elapsed = time.monotonic() - start
                        if elapsed > config.timeout:
                            raise TimeoutError(
                                f"{func.__name__} timed out after {elapsed:.2f}s",
                                timeout=config.timeout,
                            )
                        return result
                    else:
                        return func(*args, **kwargs)
                except Exception as e:  # noqa: BLE001
                    state.last_error = e
                    if state.attempts >= config.max_attempts:
                        logger.error(
                            "Retry exhausted for %s after %d attempts: %s",
                            func.__name__,
                            state.attempts,
                            str(e),
                        )
                        raise RetryExhaustedError(
                            f"{func.__name__} failed after {config.max_attempts} attempts",
                            attempts=config.max_attempts,
                            last_error=e,
                        ) from e

                    logger.warning(
                        "Attempt %d/%d for %s failed: %s. Retrying in %.2fs...",
                        state.attempts,
                        config.max_attempts,
                        func.__name__,
                        str(e),
                        delay,
                    )
                    time.sleep(delay)
                    state.total_delay += delay
                    delay = min(delay * config.exponential_base, config.max_delay)

            raise RetryExhaustedError(
                f"{func.__name__} failed after {state.attempts} attempts",
                attempts=state.attempts,
                last_error=state.last_error or Exception("Unknown error"),
            )

        return wrapper

    return decorator


async def with_timeout_async(
    timeout: float,
    message: str | None = None,
) -> Callable[[Callable[..., Coroutine[Any, Any, T]]], Callable[..., Coroutine[Any, Any, T]]]:
    """Decorator to add timeout to an async function.

    Args:
        timeout: Timeout in seconds.
        message: Custom error message.

    Returns:
        Decorated async function with timeout.
    """

    def decorator(
        func: Callable[..., Coroutine[Any, Any, T]],
    ) -> Callable[..., Coroutine[Any, Any, T]]:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            try:
                return await asyncio.wait_for(
                    func(*args, **kwargs),
                    timeout=timeout,
                )
            except asyncio.TimeoutError as e:
                raise TimeoutError(
                    message or f"{func.__name__} timed out after {timeout}s",
                    timeout=timeout,
                ) from e

        return wrapper

    return decorator


async def with_retry_async(
    config: RetryConfig | None = None,
) -> Callable[[Callable[..., Coroutine[Any, Any, T]]], Callable[..., Coroutine[Any, Any, T]]]:
    """Decorator to add retry behavior to an async function.

    Args:
        config: Retry configuration. Uses defaults if None.

    Returns:
        Decorated async function with retry.
    """
    if config is None:
        config = RetryConfig()

    def decorator(
        func: Callable[..., Coroutine[Any, Any, T]],
    ) -> Callable[..., Coroutine[Any, Any, T]]:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            state = RetryState()
            delay = config.initial_delay

            while state.attempts < config.max_attempts:
                state.attempts += 1
                try:
                    result = await asyncio.wait_for(
                        func(*args, **kwargs),
                        timeout=config.timeout,
                    )
                    return result
                except asyncio.TimeoutError as e:
                    state.last_error = TimeoutError(
                        str(e), timeout=e.args[0] if e.args else config.timeout or 0
                    )
                except Exception as e:  # noqa: BLE001
                    state.last_error = e

                if state.attempts >= config.max_attempts:
                    logger.error(
                        "Retry exhausted for %s after %d attempts: %s",
                        func.__name__,
                        state.attempts,
                        str(state.last_error),
                    )
                    raise RetryExhaustedError(
                        f"{func.__name__} failed after {config.max_attempts} attempts",
                        attempts=config.max_attempts,
                        last_error=state.last_error or Exception("Unknown error"),
                    ) from state.last_error

                logger.warning(
                    "Attempt %d/%d for %s failed: %s. Retrying in %.2fs...",
                    state.attempts,
                    config.max_attempts,
                    func.__name__,
                    str(state.last_error),
                    delay,
                )
                await asyncio.sleep(delay)
                state.total_delay += delay
                delay = min(delay * config.exponential_base, config.max_delay)

            raise RetryExhaustedError(
                f"{func.__name__} failed after {state.attempts} attempts",
                attempts=state.attempts,
                last_error=state.last_error or Exception("Unknown error"),
            )

        return wrapper

    return decorator


def retry_with_backoff(
    max_attempts: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
) -> Callable[[Callable[..., T]], Callable[..., T]]:
    """Convenience decorator for retry with exponential backoff.

    Args:
        max_attempts: Maximum number of retry attempts.
        initial_delay: Initial delay in seconds.
        max_delay: Maximum delay in seconds.
        exponential_base: Base for exponential backoff.

    Returns:
        Decorated function with retry.
    """
    config = RetryConfig(
        max_attempts=max_attempts,
        initial_delay=initial_delay,
        max_delay=max_delay,
        exponential_base=exponential_base,
    )
    return with_retry(config)
