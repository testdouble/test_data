class MetaBoop < ApplicationRecord
  def readonly?
    true
  end

  def self.refresh_materialized_view
    @refresh_materialized_view_count ||= 0
    connection.execute "refresh materialized view meta_boops"
    @refresh_materialized_view_count += 1
  end

  def self.reset_refresh_materialized_view_count
    @refresh_materialized_view_count = 0
  end

  class << self
    attr_reader :refresh_materialized_view_count
  end
end
