# frozen_string_literal: true

class SitemapController < ApplicationController
  skip_before_action :authenticate_user!

  feature_category :metrics

  def show
    return render_404 unless Gitlab.com?
    return render_404 unless Feature.enabled?(:gitlab_org_sitemap)

    respond_to do |format|
      format.xml do
        response = Sitemap::CreateService.new.execute

        xml_data = if response.success?
                     response.payload[:sitemap]
                   else
                     xml_error(response.message)
                   end

        render inline: xml_data
      end
    end
  end

  private

  def xml_error(message)
    xml_builder = Builder::XmlMarkup.new(indent: 2)
    xml_builder.instruct!
    xml_builder.error message
  end
end
