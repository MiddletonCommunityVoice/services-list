const options = {
  appId: '6CTZTIP7UD',
  apiKey: '2ac20de2c4e9354e3521a1db515f00c2',
  indexName: 'prod_BH4',
  searchFunction: function(helper) {
    let searchResults = document.getElementById("hits");

    if (helper.state.query === '') {
      searchResults.style.display = "none";
      return;
    }

    helper.search();
    searchResults.style.display = "inline";
  }
};

const search = instantsearch(options);

// initialize SearchBox
search.addWidget(
  instantsearch.widgets.searchBox({
    container: '#search-box',
    placeholder: 'Search for services',
    magnifier: false
  })
);

// initialize hits widget
search.addWidget(
  instantsearch.widgets.hits({
    container: '#hits',

    transformData: {
      item: function(original) {
        original.tags_snakecase = original.tags.map(tag => {
          return tag
            .toLowerCase()
            .replace(/ /g,'-')
            .replace(/[^\w-]+/g,'')
        });
        return original;
      }
    },

    templates: {
      empty: 'No results',
      item: '<li class="card"><a href="{{uri}}">{{{_highlightResult.title.value}}}</a> <ul class="tags">{{#tags_snakecase}}<li class="tag"><a class="button button-tag" href="/tags/{{.}}">{{{.}}}</a></li>{{/tags_snakecase}}</ul>{{{_highlightResult.content.value}}}</li>'
    }
  })
);

search.start();
