const dateValues = date => {
  return {
    day: date.getDay(),
    date: date.getDate(),
    month: date.getMonth(),
    year: date.getFullYear(),
    time: date.getTime(),
  };
};

export { dateValues };
