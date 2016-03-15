(function() {
    var ComponentRegistry, MyComposerButton, WunderlistSidebar, activate, deactivate, _ref;

    ComponentRegistry = require('nylas-exports').ComponentRegistry;

    _ref = require('../lib/main'), activate = _ref.activate, deactivate = _ref.deactivate;

    WunderlistSidebar = require('../lib/wunderlist-sidebar');

    describe("activate", function() {
        return it("should register the sidebar", function() {
            spyOn(ComponentRegistry, 'register');
            activate();
            return expect(ComponentRegistry.register).toHaveBeenCalledWith(WunderlistSidebar, {
                role: 'MessageListSidebar:ContactCard'
            });
        });
    });

    describe("deactivate", function() {
        return it("should unregister the sidebar", function() {
            spyOn(ComponentRegistry, 'unregister');
            deactivate();
            return expect(ComponentRegistry.unregister).toHaveBeenCalledWith(WunderlistSidebar);
        });
    });

}).call(this);
