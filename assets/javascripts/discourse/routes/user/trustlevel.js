import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class UserTrustLevelDisplayRoute extends DiscourseRoute {
  model() {
    const user = this.modelFor("user");
    return ajax(`/trustlevel/progress/${user.username}.json`).catch(
      popupAjaxError
    );
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    const user = this.modelFor("user");
    controller.set("user", user);
  }
}
