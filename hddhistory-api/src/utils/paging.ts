export const getPagination = (parameters: { page: number; take: number }) => {
  const { page, take } = parameters;
  return page && take ? { skip: (page - 1) * take, take, page } : {};
};
