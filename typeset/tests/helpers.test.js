const { assertTrue } = require('../helpers')

describe('assertTrue', () => {
  it('throws on false', () => {
    expect(
      () => assertTrue(false, 'whiskey-xray-yankee-zulu')
    ).toThrow('whiskey-xray-yankee-zulu')
  })
})
