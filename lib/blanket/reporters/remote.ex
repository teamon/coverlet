defmodule Blanket.Reporters.Remote do
  require Logger

  @type snapshot :: %{
          commit: %{
            sha: binary,
            message: binary,
            branch: binary,
            date: binary,
            author_email: binary,
            author_name: binary,
            commiter_email: binary,
            comitter_name: binary
          },
          source: %{
            version: binary
          },
          github: %{
            pr: binary
          },
          files: %{
            binary => [
              %{
                content: binary,
                module: module,
                lines: [{non_neg_integer, non_neg_integer}]
              }
            ]
          }
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
      source: %{
        version: version
      },
      commit: commit(),
      files: coverage
    }

    payload = :erlang.term_to_binary(snapshot)

    url = '#{endpoint}/api/v1/snapshots'

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
        System.halt(1)

      error ->
        Logger.error("Error sending raport to Blanket")
        Logger.error(inspect(error))
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

  defp parse("author_name " <> name, info), do: Map.put(info, :author_name, name)
  defp parse("author_email " <> email, info), do: Map.put(info, :author_email, email)
  defp parse("sha " <> sha, info), do: Map.put(info, :sha, sha)
  defp parse("branch " <> branch, info), do: Map.put(info, :branch, branch)
  defp parse("", info), do: info
end
