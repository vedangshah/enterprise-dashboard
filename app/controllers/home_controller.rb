# example_controller.rb
class HomeController < ApplicationController

	get '/' do
    enterprise = get_enterprise

    # Get segments data
    smart_segments = enterprise.segments.select { |x| x.intelligence }
    @seg_data = []
    smart_segments.each do |x|
      i = x.data(Time.now)
      if i
        @seg_data << { title: x.name.split(' ')[0], value: i.value[1].round(2) }
      end
    end

    # Get the conversions data
    @conv_data = Octo::Conversions.types.values.collect do |type_val|
      Octo::Conversions.data(enterprise.id, type_val, 3.days.ago..Time.now)
    end.flatten.group_by do |x|
      x.ts
    end.inject([]) do |r,e|
      key = e[0]
      values = e[1]
      r << values.inject({}) do |rs, el|
        val = (el.type == 1) ? 'Notification' : 'Newsfeed'
        rs[val] = el.value.round(2)
        rs
      end.merge( ts: key )
      r
    end

    # Get the trending data
    @trend_data = [Octo::ProductTrend, Octo::CategoryTrend, Octo::TagTrend].inject({}) do |trend_data, trend_class|
      trend_data[trend_text_for(trend_class)] = trend_class.send(:get_trending, enterprise.id, Octo::Counter::TYPE_MINUTE, limit: 3)
      trend_data
    end

    # Get the funnels data
    @funnel_data = enterprise.funnels.first(3)

    # Get the Api Calls happened in last few minutes
    @api_data = []
    apihits = Octo::ApiHit.where(
      enterprise_id: enterprise.id,
      type: Octo::Counter::TYPE_MINUTE,
      ts: 5.minutes.ago.utc..Time.now.floor.utc
    ).group_by { |x| x.ts }
    apihits.values.each_with_index do |counters, index|
      @api_data << { x: index, y: counters.inject(0) { |sum, counter| sum += counter.count } }
    end
    if @api_data.count > 0
      @api_count = @api_data[@api_data.length-1][:y]
    else
      @api_count = 0
    end

    if enterprise.fakedata?
      @today = {
        'Most Engaged Users' => {
          :title => 'Down by 0.1%',
          :wow => 0.6,
          :oye => -0.1
        },
        'Notifications Sent' => {
          :title => 'Unchanged',
          :wow => 0.5,
          :oye => 0.0
        },
        'Feed Engagement' => {
          :title => 'Up by 8%',
          :wow => 4.5,
          :oye => 8
        }
      }
    end
  	erb :home
	end

end
