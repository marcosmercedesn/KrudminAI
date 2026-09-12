import { Application } from "@hotwired/stimulus"
import FilterPanelController from "./controllers/filter_panel_controller"
import ThemeController from "./controllers/theme_controller"

const application = Application.start()
application.register("krudmin-ai-filter-panel", FilterPanelController)
application.register("krudmin-ai-theme", ThemeController)