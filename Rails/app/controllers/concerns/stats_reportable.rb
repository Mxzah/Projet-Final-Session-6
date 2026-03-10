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

    # Validate date formats and coherence
    start_date = params[:start_date]
    end_date = params[:end_date]

    if start_date.present?
      return render_error(I18n.t("controllers.stats.invalid_start_date")) unless valid_date?(start_date)
    end

    if end_date.present?
      return render_error(I18n.t("controllers.stats.invalid_end_date")) unless valid_date?(end_date)
    end

    if start_date.present? && end_date.present? && start_date > end_date
      return render_error(I18n.t("controllers.stats.end_before_start"))
    end

    # Date filters go into extra (for JOIN conditions), not into WHERE
    # so LEFT JOINed items without orders are not excluded
    if params[:category_ids].present?
      ids = Array(params[:category_ids]).map(&:to_i)
      conditions << "#{config[:category_column]} IN (#{ids.map { '?' }.join(', ')})"
      binds.concat(ids)
    end

    where_clause = conditions.any? ? "WHERE #{conditions.join(' AND ')}" : ""
    sanitized_where = ActiveRecord::Base.sanitize_sql_array([where_clause] + binds)

    extra = { start_date: params[:start_date], end_date: params[:end_date] }
    sql = config[:sql].call(sanitized_where, extra)
    rows = ActiveRecord::Base.connection.exec_query(sql).to_a

    render_success(data: { columns: config[:columns], rows: rows })
  end

  private

  def valid_date?(str)
    return false unless str.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.strptime(str, "%Y-%m-%d")
    true
  rescue Date::Error
    false
  end
end
