defmodule Deploy do
  @moduledoc """
  A CLI helper to assist with deploying. It will do a couple of sanity
  checks before pushing to the staging branch which triggers a deployment.

  usage: `mix stage`
  """

  import IO.ANSI

  def run(target) do
    with :ok <- check_git_dirtyness(),
         {:ok, branch} <- current_git_branch(),
         :ok <- check_deploying_non_main_to_prod(branch, target),
         :ok <- confirm(branch, target),
         :ok <- git_push(branch, target) do
      "Triggered deployment" |> green() |> IO.puts()
    else
      _ ->
        "Exiting" |> red() |> IO.puts()
        System.stop(1)
    end
  end

  defp git_push(branch, target) do
    case System.cmd("git", ["push", "--force", "origin", "#{branch}:#{target}"]) do
      {_, 0} ->
        :ok
      {error, _} ->
        IO.puts(error)
        :error
    end
  end

  defp check_git_dirtyness() do
    case System.cmd("git", ["diff", "--stat"]) do
      {"", 0} ->
        :ok

      _ ->
        "You have uncommitted changes. Please resolve your changes first." |> red() |> IO.puts()
        :error
    end
  end

  defp check_deploying_non_main_to_prod("master", "master"), do: :ok
  defp check_deploying_non_main_to_prod(_, "master") do
    "You are not on the master branch and trying to deploy to production" |> red() |> IO.puts()
    :error
  end
  defp check_deploying_non_main_to_prod(_, _), do: :ok

  defp current_git_branch() do
    with {branch, 0} <- System.cmd("git", ["symbolic-ref", "HEAD", "--short"]) do
      {:ok, String.trim(branch)}
    end
  end

  defp confirm(branch, target) do
    "Do you want to deploy #{yellow(branch)} to #{yellow(target)}" |> IO.puts()
    response = "Is this correct? [y/n]: " |> IO.gets() |> String.trim()
    if response =~ ~r{y|Y} do
      :ok
    else
      :error
    end
  end

  def bright(text), do: [bright(), white(), text, reset()] |> Enum.join()
  def red(text), do: [red(), bright(), text, reset()] |> Enum.join()
  def yellow(text), do: [yellow(), text, reset()] |> Enum.join()
  def green(text), do: [green(), text, reset()] |> Enum.join()
end

target = case System.argv() do
  ["production"] -> "master"
  [target] -> target
  [] -> "staging"
end

Deploy.run(target)
