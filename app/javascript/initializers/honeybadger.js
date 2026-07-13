
if (process.env.RAILS_ENV === 'production') {

  const IGNORE_ERRORS = [
    /AbortError/,
    /UnhandledPromiseRejectionWarning: {}/,
    /UnhandledPromiseRejectionWarning.*Load failed/,
    /UnhandledPromiseRejectionWarning: Object Not Found Matching/,
    /UnhandledPromiseRejectionWarning.*Failed to fetch/,
    /ResizeObserver loop completed with undelivered notifications./,
  ]

  
}
