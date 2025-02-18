$(document).ready(function() {
  $('.tag-selector').on('click', '.tag', function() {
    let parent = $(this).parent();
    
    if (parent.hasClass('multi')) {
      // 多选逻辑
      $(this).toggleClass('selected');
      let selectedValues = parent.find('.selected').map(function() {
        return $(this).data('value');
      }).get();
      Shiny.setInputValue(parent.attr('id'), selectedValues, {priority: "event"});
    } else {
      // 单选逻辑
      $(this).siblings().removeClass('selected');
      $(this).addClass('selected');
      let selectedValue = $(this).data('value');
      Shiny.setInputValue(parent.attr('id'), selectedValue, {priority: "event"});
    }
  });

  // 处理自定义消息，用于更新标签选择器的内容
  Shiny.addCustomMessageHandler('updateTagSelector', function(message) {
    $('#' + message.inputId).html(message.tags); // 更新标签内容
  });
});