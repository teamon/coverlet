defmodule Blanket.Reporters.Remote do
  require Logger

  @type snapshot :: %{
          commit: %{
            sha: binary,
            message: binary,
            branch: binary,
            author_email: binary,
            author_name: binary,
            author_date: binary,
            committer_email: binary,
            committer_name: binary,
            committer_date: binary
          },
          source: %{
            version: binary
          },
          github: %{
            pr: binary
          },
          files: [
            %{
              path: binary,
              lines: [{non_neg_integer, non_neg_integer}]
            }
          ]
        }

  def call(coverage) do
    case Blanket.token() do
      :unset -> IO.puts("Missing BLANKET_TOKEN, not sending")
      token -> report(coverage, token, Blanket.endpoint(), Blanket.version())
    end
  end

  def report(coverage, token, endpoint, version) do
    {:ok, _} = Application.ensure_all_started(:inets)

    snapshot = %{
      reporter: %{
        name: "blanket-elixir",
        version: version
      },
      commit: commit(),
      files: coverage
    }

    payload = :erlang.term_to_binary(snapshot)

    url = '#{endpoint}/api/v0/snapshots'

    headers = [
      {'user-agent', 'blanket-elixir #{version}'},
      {'authorization', '#{token}'}
    ]

    case :httpc.request(:post, {url, headers, 'application/vnd.blanket+erlang', payload}, [], []) do
      {:ok, {{_, 201, _}, _headers, _body}} ->
        Logger.info("Code coverage report successfully sent to Blanket")
        :ok

      {:ok, {{_, 401, _}, _headers, _body}} ->
        Logger.error("Error sending raport to Blanket - The token is invalid")
        Logger.error("Check the value of BLANKET_TOKEN and try again")
        Logger.flush()
        System.halt(1)

      error ->
        Logger.error("Error sending raport to Blanket")
        Logger.error(inspect(error))
        Logger.flush()
        System.halt(2)
    end
  end

  defp commit do
    script = Path.join(:code.priv_dir(:blanket), "git-info.sh")
    {out, 0} = System.cmd("bash", [script])

    out
    |> String.split("\n")
    |> Enum.reduce(%{}, &parse/2)
  end

  defp parse("sha " <> sha, info), do: Map.put(info, :sha, sha)
  defp parse("message " <> message, info), do: Map.put(info, :message, message)
  defp parse("branch " <> branch, info), do: Map.put(info, :branch, branch)
  defp parse("author_email " <> email, info), do: Map.put(info, :author_email, email)
  defp parse("author_name " <> name, info), do: Map.put(info, :author_name, name)
  defp parse("author_date " <> date, info), do: Map.put(info, :author_date, date)
  defp parse("committer_email " <> email, info), do: Map.put(info, :committer_email, email)
  defp parse("committer_name " <> name, info), do: Map.put(info, :committer_name, name)
  defp parse("committer_date " <> date, info), do: Map.put(info, :committer_date, date)
  defp parse("", info), do: info
end
