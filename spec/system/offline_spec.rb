require 'rails_helper'

RSpec.describe 'Offline fallback', type: :system, js: true do
  after do
    back_online
    page.execute_script(<<~JS)
      navigator.serviceWorker.getRegistrations()
        .then((registrations) => registrations.forEach((registration) => registration.unregister()))
    JS
  end

  it 'serves the precached offline page when the network is unreachable', :chrome do
    visit new_session_path
    wait_for_service_worker_control

    go_offline
    visit root_path

    expect(page).to have_content "You're offline"
    expect(page).to have_button 'Try again'
  end

  private

  # The worker calls skipWaiting/clients.claim on install, so the page becomes
  # controlled shortly after registration; poll until that happens.
  def wait_for_service_worker_control
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.1 until page.evaluate_script('navigator.serviceWorker.controller != null')
    end
  end

  # Navigation requests on a controlled page are fetched by the service
  # worker, which runs in its own CDP target that the driver-level network
  # conditions don't reach, so both targets must go offline.
  def go_offline
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.context.set_offline(true)
    end
  end

  def back_online
    page.driver.with_playwright_page do |playwright_page|
      playwright_page.context.set_offline(false)
    end
  end
end
