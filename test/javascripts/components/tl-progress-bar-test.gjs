import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";

module("Integration | Component | tl-progress-bar", function (hooks) {
  setupRenderingTest(hooks);

  test("it renders a progress bar with correct width", async function (assert) {
    this.set("percentage", 75);

    await render(hbs`<TlProgressBar @percentage={{this.percentage}} />`);

    assert.dom(".tl-progress-bar__fill").hasAttribute("style", /width: 75%/);
  });

  test("it caps width at 100%", async function (assert) {
    this.set("percentage", 150);

    await render(hbs`<TlProgressBar @percentage={{this.percentage}} />`);

    assert.dom(".tl-progress-bar__fill").hasAttribute("style", /width: 100%/);
  });

  test("it displays the label when provided", async function (assert) {
    this.set("percentage", 50);
    this.set("label", "50%");

    await render(
      hbs`<TlProgressBar @percentage={{this.percentage}} @label={{this.label}} />`
    );

    assert.dom(".tl-progress-bar__label").hasText("50%");
  });

  test("it applies --complete modifier at 100%", async function (assert) {
    this.set("percentage", 100);

    await render(hbs`<TlProgressBar @percentage={{this.percentage}} />`);

    assert.dom(".tl-progress-bar__fill.--complete").exists();
  });

  test("it applies --warning modifier with warning variant", async function (assert) {
    this.set("percentage", 40);

    await render(
      hbs`<TlProgressBar @percentage={{this.percentage}} @variant="warning" />`
    );

    assert.dom(".tl-progress-bar__fill.--warning").exists();
  });
});
