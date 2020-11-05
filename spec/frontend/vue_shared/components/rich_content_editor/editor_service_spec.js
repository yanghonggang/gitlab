import {
  generateToolbarItem,
  addCustomEventListener,
  removeCustomEventListener,
  registerHTMLToMarkdownRenderer,
  addImage,
  insertVideo,
  getMarkdown,
  getEditorOptions,
} from '~/vue_shared/components/rich_content_editor/services/editor_service';
import buildHTMLToMarkdownRenderer from '~/vue_shared/components/rich_content_editor/services/build_html_to_markdown_renderer';
import buildCustomRenderer from '~/vue_shared/components/rich_content_editor/services/build_custom_renderer';
import sanitizeHTML from '~/vue_shared/components/rich_content_editor/services/sanitize_html';

jest.mock('~/vue_shared/components/rich_content_editor/services/build_html_to_markdown_renderer');
jest.mock('~/vue_shared/components/rich_content_editor/services/build_custom_renderer');
jest.mock('~/vue_shared/components/rich_content_editor/services/sanitize_html');

describe('Editor Service', () => {
  let mockInstance;
  let event;
  let handler;
  const parseHtml = str => {
    const wrapper = document.createElement('div');
    wrapper.innerHTML = str;
    return wrapper.firstChild;
  };

  beforeEach(() => {
    mockInstance = {
      eventManager: { addEventType: jest.fn(), removeEventHandler: jest.fn(), listen: jest.fn() },
      editor: {
        exec: jest.fn(),
        isWysiwygMode: jest.fn(),
        getSquire: jest.fn(),
        insertText: jest.fn(),
      },
      invoke: jest.fn(),
      toMarkOptions: {
        renderer: {
          constructor: {
            factory: jest.fn(),
          },
        },
      },
    };
    event = 'someCustomEvent';
    handler = jest.fn();
  });

  describe('generateToolbarItem', () => {
    const config = {
      icon: 'bold',
      command: 'some-command',
      tooltip: 'Some Tooltip',
      event: 'some-event',
    };

    const generatedItem = generateToolbarItem(config);

    it('generates the correct command', () => {
      expect(generatedItem.options.command).toBe(config.command);
    });

    it('generates the correct event', () => {
      expect(generatedItem.options.event).toBe(config.event);
    });

    it('generates a divider when isDivider is set to true', () => {
      const isDivider = true;

      expect(generateToolbarItem({ isDivider })).toBe('divider');
    });
  });

  describe('addCustomEventListener', () => {
    it('registers an event type on the instance and adds an event handler', () => {
      addCustomEventListener(mockInstance, event, handler);

      expect(mockInstance.eventManager.addEventType).toHaveBeenCalledWith(event);
      expect(mockInstance.eventManager.listen).toHaveBeenCalledWith(event, handler);
    });
  });

  describe('removeCustomEventListener', () => {
    it('removes an event handler from the instance', () => {
      removeCustomEventListener(mockInstance, event, handler);

      expect(mockInstance.eventManager.removeEventHandler).toHaveBeenCalledWith(event, handler);
    });
  });

  describe('addImage', () => {
    it('calls the exec method on the instance', () => {
      const mockImage = { imageUrl: 'some/url.png', description: 'some description' };

      addImage(mockInstance, mockImage);

      expect(mockInstance.editor.exec).toHaveBeenCalledWith('AddImage', mockImage);
    });
  });

  describe('insertVideo', () => {
    const mockUrl = 'some/url';
    const htmlString = `<figure contenteditable="false" class="gl-relative gl-h-0 video_container"><iframe class="gl-absolute gl-top-0 gl-left-0 gl-w-full gl-h-full" width="560" height="315" frameborder="0" src="some/url"></iframe></figure>`;
    const mockInsertElement = jest.fn();

    beforeEach(() =>
      mockInstance.editor.getSquire.mockReturnValue({ insertElement: mockInsertElement }),
    );

    describe('WYSIWYG mode', () => {
      it('calls the insertElement method on the squire instance with an iFrame element', () => {
        mockInstance.editor.isWysiwygMode.mockReturnValue(true);

        insertVideo(mockInstance, mockUrl);

        expect(mockInstance.editor.getSquire().insertElement).toHaveBeenCalledWith(
          parseHtml(htmlString),
        );
      });
    });

    describe('Markdown mode', () => {
      it('calls the insertText method on the editor instance with the iFrame element HTML', () => {
        mockInstance.editor.isWysiwygMode.mockReturnValue(false);

        insertVideo(mockInstance, mockUrl);

        expect(mockInstance.editor.insertText).toHaveBeenCalledWith(htmlString);
      });
    });
  });

  describe('getMarkdown', () => {
    it('calls the invoke method on the instance', () => {
      getMarkdown(mockInstance);

      expect(mockInstance.invoke).toHaveBeenCalledWith('getMarkdown');
    });
  });

  describe('registerHTMLToMarkdownRenderer', () => {
    let baseRenderer;
    const htmlToMarkdownRenderer = {};
    const extendedRenderer = {};

    beforeEach(() => {
      baseRenderer = mockInstance.toMarkOptions.renderer;
      buildHTMLToMarkdownRenderer.mockReturnValueOnce(htmlToMarkdownRenderer);
      baseRenderer.constructor.factory.mockReturnValueOnce(extendedRenderer);

      registerHTMLToMarkdownRenderer(mockInstance);
    });

    it('builds a new instance of the HTML to Markdown renderer', () => {
      expect(buildHTMLToMarkdownRenderer).toHaveBeenCalledWith(baseRenderer);
    });

    it('extends base renderer with the HTML to Markdown renderer', () => {
      expect(baseRenderer.constructor.factory).toHaveBeenCalledWith(
        baseRenderer,
        htmlToMarkdownRenderer,
      );
    });

    it('replaces the default renderer with extended renderer', () => {
      expect(mockInstance.toMarkOptions.renderer).toBe(extendedRenderer);
    });
  });

  describe('getEditorOptions', () => {
    const externalOptions = {
      customRenderers: {},
    };
    const renderer = {};

    beforeEach(() => {
      buildCustomRenderer.mockReturnValueOnce(renderer);
    });

    it('generates a configuration object with a custom HTML renderer and toolbarItems', () => {
      expect(getEditorOptions()).toHaveProp('customHTMLRenderer', renderer);
      expect(getEditorOptions()).toHaveProp('toolbarItems');
    });

    it('passes external renderers to the buildCustomRenderers function', () => {
      getEditorOptions(externalOptions);
      expect(buildCustomRenderer).toHaveBeenCalledWith(externalOptions.customRenderers);
    });

    it('uses the internal sanitizeHTML service for HTML sanitization', () => {
      const options = getEditorOptions();
      const html = '<div></div>';

      options.customHTMLSanitizer(html);

      expect(sanitizeHTML).toHaveBeenCalledWith(html);
    });
  });
});
