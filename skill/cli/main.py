"""CLI entry point for skill."""

from __future__ import annotations

import typer

app = typer.Typer(
    name="skill",
    help="Skill evaluation and management framework",
    add_completion=False,
)


@app.command()
def evaluate(
    target: str = typer.Argument(..., help="Target skill or prompt to evaluate"),
    output: str | None = typer.Option(None, "--output", "-o", help="Output file for results"),
    verbose: bool = typer.Option(False, "--verbose", "-v", help="Verbose output"),
) -> None:
    """Evaluate a skill or prompt using multi-dimensional assessment."""
    typer.echo(f"Evaluating: {target}")
    if output:
        typer.echo(f"Output will be saved to: {output}")
    if verbose:
        typer.echo("Verbose mode enabled")


@app.command()
def create(
    prompt: str = typer.Argument(..., help="Skill description or prompt"),
    target_tier: str = typer.Option(
        "BRONZE", "--target", "-t", help="Target tier: GOLD, SILVER, BRONZE"
    ),
    dry_run: bool = typer.Option(False, "--dry-run", help="Preview without execution"),
) -> None:
    """Create a new skill from a prompt."""
    typer.echo(f"Creating skill from: {prompt}")
    typer.echo(f"Target tier: {target_tier}")
    if dry_run:
        typer.echo("Dry run mode - no changes will be made")


@app.command()
def evolve(
    skill_file: str = typer.Argument(..., help="Skill file to evolve"),
    iterations: int = typer.Option(1, "--iterations", "-n", help="Number of evolution iterations"),
) -> None:
    """Evolve an existing skill."""
    typer.echo(f"Evolving skill: {skill_file}")
    typer.echo(f"Iterations: {iterations}")


@app.command()
def version() -> None:
    """Show version information."""
    from skill import __version__

    typer.echo(f"skill version {__version__}")


if __name__ == "__main__":
    app()
