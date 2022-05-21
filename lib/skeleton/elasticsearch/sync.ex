defmodule Skeleton.Elasticsearch.Sync do
  alias Skeleton.Elasticsearch.Config

  def run(opts) do
    app = Config.get_app_name()

    app
    |> Application.get_env(:elasticsearch_modules)
    |> Enum.each(&do_sync(app, &1, opts || []))
  end

  defp do_sync(app, module, sync_modules) do
    app
    |> Application.get_env(module)
    |> Keyword.get(:sync_modules, [])
    |> Enum.filter(fn {sync_module, _func, _args} ->
      str_module = String.replace_prefix(to_string(sync_module), "Elixir.", "")
      Enum.empty?(sync_modules) || Enum.member?(sync_modules, str_module)
    end)
    |> inform_which_modules_will_be_indexed(sync_modules)
    |> Enum.each(fn {sync_module, func, args} ->
      IO.puts("Start syncing #{sync_module}")
      apply(sync_module, func, args)
    end)
  end

  defp inform_which_modules_will_be_indexed(filtered_config_sync_modules, user_sync_modules) do
    cond  do
      filtered_config_sync_modules == [] and user_sync_modules != [] ->
        IO.puts("""
        \n
        No indexers found with the names #{user_sync_modules}, you must pass the full name of the indexer module!

        Example: MyApp.Accounts.UserIndexer
        """)
        IO.puts("")

      filtered_config_sync_modules == [] ->
        IO.puts("\nNo indexers found! You need to configure `sync_modules` in your Skeleton Elasticsearch settings\n")

      true ->
        module_names =
          filtered_config_sync_modules
          |> Enum.map(fn {module_name, _, _} -> module_name |> to_string() |> String.replace("Elixir.", "") end)
          |> Enum.join(", ")

        IO.puts("\nThe modules #{module_names} will be indexed!\n")
    end

    filtered_config_sync_modules
  end
end
