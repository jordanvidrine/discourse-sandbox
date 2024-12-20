import Component from "@glimmer/component";
import Form from "discourse/components/form";

export default class ComponentSettingsSelect extends Component {

  <template>
      <Form as |form|>
        <form.Field
          @title={{this.args.label}}
          @name="field_type"
          @format="large"
          @validation="required"
          as |field|
        >
          <field.Select as |select|>
            {{#each this.args.values as |valueOption|}}
              <select.Option
                @value={{valueOption}}
              >{{valueOption}}</select.Option>
            {{/each}}
          </field.Select>
        </form.Field>
        // TODO: add submit button
      </Form>
  </template>
}
