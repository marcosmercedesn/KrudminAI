import { Application } from "@hotwired/stimulus"
import FilterPanelController from "krudmin_ai/controllers/filter_panel_controller"
import NestedFieldsController from "krudmin_ai/controllers/nested_fields_controller"
import NavigationController from "krudmin_ai/controllers/navigation_controller"
import ThemeController from "krudmin_ai/controllers/theme_controller"
import RemoteBelongsToController from "krudmin_ai/controllers/remote_belongs_to_controller"
import FormValidationController from "krudmin_ai/controllers/form_validation_controller"

const application = Application.start()
application.register("krudmin-ai-filter-panel", FilterPanelController)
application.register("krudmin-ai-nested-fields", NestedFieldsController)
application.register("krudmin-ai-navigation", NavigationController)
application.register("krudmin-ai-theme", ThemeController)
application.register("krudmin-ai-remote-belongs-to", RemoteBelongsToController)
application.register("krudmin-ai-form-validation", FormValidationController)