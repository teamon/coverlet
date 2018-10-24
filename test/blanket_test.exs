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
      Bypass.expect_once(bypass, "POST", "/api/v1/snapshots", fn conn ->
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
      Bypass.expect_once(bypass, "POST", "/api/v1/snapshots", fn conn ->
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
      Bypass.expect_once(bypass, "POST", "/api/v1/snapshots", fn conn ->
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
