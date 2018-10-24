defmodule Blanket.Reporters.Remote do
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
    Application.ensure_all_started(:inets) |> IO.inspect()

    snapshot = %{
      source: %{
        version: Blanket.version()
      },
      commit: commit(),
      files: coverage
    }

    # IO.inspect(snapshot)

    payload = :erlang.term_to_binary(snapshot)

    url = '#{Blanket.endpoint()}/api/v1/snapshots'

    headers = [
      {'user-agent', 'blanket-elixir #{Blanket.version()}'},
      {'authorization', '#{Blanket.token()}'}
    ]

    {:ok, response} =
      :httpc.request(:post, {url, headers, 'application/vnd.blanket+erlang', payload}, [], [])

    IO.inspect(response)
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
