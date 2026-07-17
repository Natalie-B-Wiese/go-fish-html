Data::Country = Data.define(:id, :name, :states) do
  include DataFor::Model

  config :countries

  private

  def cast_states(data)
    Array(data).map { Data::State[**it] }
  end
end
