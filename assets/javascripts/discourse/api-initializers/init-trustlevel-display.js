import { apiInitializer } from "discourse/lib/api";
import I18n from "I18n";
import TlProgressSummary from "../components/tl-progress-summary";
import TlProgressSummaryCard from "../components/tl-progress-summary-card";

export default apiInitializer((api) => {
  const currentUser = api.getCurrentUser();
  if (!currentUser) {
    return;
  }

  // Inject progress into user summary stats section
  api.renderInOutlet("user-summary-stat", TlProgressSummary);

  // Inject progress into user card (before badges)
  api.renderInOutlet("user-card-before-badges", TlProgressSummaryCard);

  // Add sidebar link to own progress page
  api.addCommunitySectionLink({
    name: "trustlevel",
    route: "user.trustlevel",
    models: [currentUser.username],
    text: I18n.t("trustlevel_display.title"),
    icon: "chart-bar",
  });
});
