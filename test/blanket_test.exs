defmodule BlanketTest do
  use ExUnit.Case

  @appdir "test/example"

  @opts [
    cd: @appdir
  ]

  setup do
    File.rm_rf("#{@appdir}/cover")
    bypass = Bypass.open()

    {:ok, bypass: bypass}
  end

  describe "mix test --cover" do
    test "generate HTML (no sending without BLANKET_TOKEN)" do
      assert {_out, 0} = System.cmd("mix", ["test", "--cover"], @opts)
      assert File.exists?("#{@appdir}/cover/cover.html")
    end

    test "send report when given BLANKET_TOKEN", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/v0/snapshots", fn conn ->
        # validate content-type header
        assert ["application/vnd.blanket+erlang"] = Plug.Conn.get_req_header(conn, "content-type")

        # validate payload
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        payload = :erlang.binary_to_term(body)

        # validate files snapshot
        assert payload[:files] == [
                 %{
                   path: "lib/example.ex",
                   lines: [{3, 2}, {7, 3}, {11, 0}, {15, 1}, {21, 0}, {22, 0}]
                 }
               ]

        # send "Created" response
        Plug.Conn.resp(conn, 201, "")
      end)

      env = [
        {"BLANKET_TOKEN", "xyz"},
        {"BLANKET_ENDPOINT", "http://localhost:#{bypass.port}"}
      ]

      assert {_out, 0} = System.cmd("mix", ["test", "--cover"], [env: env] ++ @opts)
      assert File.exists?("#{@appdir}/cover/cover.html")
    end

    test "handle invalid token error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/v0/snapshots", fn conn ->
        Plug.Conn.resp(conn, 401, "Invalid token")
      end)

      env = [
        {"BLANKET_TOKEN", "xyz"},
        {"BLANKET_ENDPOINT", "http://localhost:#{bypass.port}"}
      ]

      assert {_out, 1} = System.cmd("mix", ["test", "--cover"], [env: env] ++ @opts)
      assert File.exists?("#{@appdir}/cover/cover.html")
    end

    test "handle other error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/api/v0/snapshots", fn conn ->
        Plug.Conn.resp(conn, 404, "Not found")
      end)

      env = [
        {"BLANKET_TOKEN", "xyz"},
        {"BLANKET_ENDPOINT", "http://localhost:#{bypass.port}"}
      ]

      assert {_out, 2} = System.cmd("mix", ["test", "--cover"], [env: env] ++ @opts)
      assert File.exists?("#{@appdir}/cover/cover.html")
    end

    # TODO: test "handle SSL endpoint"
  end
end
