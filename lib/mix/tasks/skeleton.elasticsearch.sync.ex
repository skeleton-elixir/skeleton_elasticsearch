defmodule Mix.Tasks.Skeleton.Elasticsearch.Sync do
  def run(args) do
    Mix.Task.run("app.start", [])

    app = Mix.Project.config()[:app]

    app
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_sync(app, &1, args || []))
  end

  defp do_sync(app, module, sync_modules) do
    app
    |> Application.get_env(module)
    |> Keyword.get(:sync_modules, [])
    |> Enum.filter(fn {sync_module, _func, _args} ->
      str_module = String.replace_prefix(to_string(sync_module), "Elixir.", "")
      Enum.empty?(sync_modules) || Enum.member?(sync_modules, str_module)
    end)
    |> Enum.each(fn {sync_module, func, args} ->
      IO.puts("Start syncing #{sync_module}")
      apply(sync_module, func, args)
    end)
  end
end
