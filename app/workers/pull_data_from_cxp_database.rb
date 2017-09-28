class PullDataFromCxpDatabaseWorker
  include Sidekiq::Worker
  def perform
    Salesman.get_data_from_sandbox_reporting
  end
end
