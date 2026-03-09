# frozen_string_literal: true

# Shared concern for stats report endpoints.
# Each controller that includes this module must define a private `stats_config` method
# returning a hash with :columns, :sql, and optional :date_column, :category_column, :base_conditions.
module StatsReportable
  extend ActiveSupport::Concern

  def stats
    config = stats_config
    conditions = (config[:base_conditions] || []).dup
    binds = []

    if params[:start_date].present?
      conditions << "#{config[:date_column]} >= ?"
      binds << params[:start_date]
    end
    if params[:end_date].present?
      conditions << "#{config[:date_column]} <= ?"
      binds << params[:end_date]
    end
    if params[:category_ids].present?
      ids = Array(params[:category_ids]).map(&:to_i)
      conditions << "#{config[:category_column]} IN (#{ids.map { '?' }.join(', ')})"
      binds.concat(ids)
    end

    where_clause = conditions.any? ? "WHERE #{conditions.join(' AND ')}" : ""
    sanitized_where = ActiveRecord::Base.sanitize_sql_array([where_clause] + binds)

    sql = config[:sql].call(sanitized_where)
    rows = ActiveRecord::Base.connection.exec_query(sql).to_a

    render_success(data: { columns: config[:columns], rows: rows })
  end
end
